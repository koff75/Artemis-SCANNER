import functools
import socket
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
from typing import Set

import dns
from dns.resolver import Answer

from artemis.config import Config
from artemis.retrying_resolver import retry


class ResolutionException(Exception):
    pass


class NoAnswer(Exception):
    pass


MAX_CNAME_NEST_DEPTH = 5


def _results_from_answer(domain: str, answer: Answer, result_type: int) -> Set[str]:
    found_results = []
    response = answer.response

    for entry in response.answer:
        if str(entry.name).rstrip(".") != domain:
            continue

        for item in entry.items:
            item = str(item).rstrip(".")

            if entry.rdtype == result_type:
                found_results.append(item)

            # CNAME
            if entry.rdtype == 5:
                for _ in range(MAX_CNAME_NEST_DEPTH):
                    # This is not the IP we want - we want to check *other records*
                    # for the IP - so we cut the trailing dot (kazet.cc. -> kazet.cc) and
                    # look for this domain in other records.
                    for subentry in response.answer:
                        if str(subentry.name).strip(".") == item and subentry.rdtype == 1:
                            found_results.append(subentry.to_text().split(" ")[-1].rstrip("."))
                            break

                        if str(subentry.name).strip(".") == item and subentry.rdtype == 2:
                            for rdataset in subentry:
                                found_results.append(rdataset.to_text().rstrip("."))
                            break

                        if str(subentry.name).strip(".") == item and subentry.rdtype == 5:
                            # CNAME refering to another CNAME record (this happens)
                            item = subentry.to_text().split(" ")[-1].rstrip(".")

    return set(found_results)


def _single_resolution_attempt(domain: str, query_type: str = "A") -> Set[str]:
    try:
        # Configure resolver with explicit timeout to prevent blocking
        resolver = dns.resolver.Resolver()
        resolver.timeout = min(Config.Limits.REQUEST_TIMEOUT_SECONDS, 5)  # Max 5 seconds per DNS query
        resolver.lifetime = min(Config.Limits.REQUEST_TIMEOUT_SECONDS * 2, 10)  # Max 10 seconds total
        
        answer = resolver.resolve(domain, query_type)

        if query_type == "A":
            result_type = 1
        elif query_type == "NS":
            result_type = 2
        else:
            raise NotImplementedError(f"Don't know how to obtain results for query {query_type}")
        return _results_from_answer(domain, answer, result_type)

    except dns.resolver.NoAnswer:
        raise NoAnswer()
    except dns.resolver.NXDOMAIN:
        return set()
    except dns.resolver.Timeout:
        raise ResolutionException(f"DNS resolution timeout for {domain}")
    except Exception as e:
        raise ResolutionException(f"Unexpected DNS status ({e})")


def _gethostbyname_with_timeout(domain: str, timeout: int = 5) -> str:
    """
    Wrapper for socket.gethostbyname with timeout using ThreadPoolExecutor.
    Compatible with both Windows and Unix.
    """
    def _resolve():
        return socket.gethostbyname(domain)
    
    with ThreadPoolExecutor(max_workers=1) as executor:
        future = executor.submit(_resolve)
        try:
            return future.result(timeout=timeout)
        except FutureTimeoutError:
            raise socket.gaierror(f"DNS resolution timeout for {domain}")


@functools.lru_cache(maxsize=8192)
def lookup(domain: str, query_type: str = "A") -> Set[str]:
    """
    :return List of IP addresses (or domains, for NS lookup)

    :raise ResolutionException if something fails
    """
    if query_type == "A":
        try:
            # First try socket.gethostbyname to lookup from hosts file
            # Use timeout to prevent indefinite blocking
            dns_timeout = min(Config.Limits.REQUEST_TIMEOUT_SECONDS, 5)
            return {_gethostbyname_with_timeout(domain, timeout=dns_timeout)}
        except (socket.gaierror, FutureTimeoutError):
            pass
    try:
        domain = domain.lower()
        return retry(_single_resolution_attempt, (domain, query_type), {})  # type: ignore
    except NoAnswer:
        return set()
