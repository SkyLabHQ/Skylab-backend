from collections import defaultdict
import requests
import json
import sys
from web3 import Web3, middleware
from ens import ENS

# Active tournament tweet: CHANGE THIS
tweet_id = "1682195441750884359"

# Twitter APP settings
bearer_token = "AAAAAAAAAAAAAAAAAAAAAHTNoQEAAAAA162K7w7ePmv1cQtqx438Xr2i4Y8%3DXamvvRacTOsEBM8vnkKU0fsrXKOnOFaBWN3fhyZaGVfGjBbbtV"
# Twitter account id
account_id = "1499603237959192577"

# Comment matching
comment_prefix = "0x"
eth_suffix = ".eth"

network_url = 'https://eth.llamarpc.com'

def bearer_oauth(r):
    """
    Method required by bearer token authentication.
    """
    r.headers["Authorization"] = f"Bearer {bearer_token}"
    r.headers["User-Agent"] = "v2TweetPython"
    return r

def handle_rate_limit_or_failure(response, expected):
    if response.status_code == 429:
        input("WARNING: Rate limited - give up and move on?")
    elif response.status_code != expected:
        raise Exception(
            "Request returned an error: {} {}".format(
                response.status_code, response.text
            )
        )

def get(url, params):
    print(f"calling {url}")
    response = requests.request("GET", url, auth=bearer_oauth, params=params)
    handle_rate_limit_or_failure(response, 200)
    return response.json()

def multi_page_obtain_data(url, params, extract_data=lambda data: data["data"]):
    data = []
    resp_data = get(url, params)

    while "meta" in resp_data and resp_data["meta"]["result_count"] > 0:
        data += extract_data(resp_data)
        if "next_token" not in resp_data["meta"]:
            break
        params["pagination_token"] = resp_data["meta"]["next_token"]
        resp_data = get(url, params)

    return data

def fetch_followers():
    url = "https://api.twitter.com/2/users/{}/followers".format(account_id)
    params = {
        "max_results": 400, 
        "user.fields": "created_at,id,username"
    }
    data = multi_page_obtain_data(url, params)

    with open("followers.temp", "w") as f:
        for entry in data:
            f.write(str(entry) + "\n")

    print("Step 1: fetch followers done. Detailed results are in followers.temp")
    return { entry["id"]: entry["username"] for entry in data }

def fetch_users_from_retweets():
    url = "https://api.twitter.com/2/tweets/{}/retweeted_by".format(tweet_id)
    params = {
        "max_results": 100, 
        "user.fields": "created_at,id,username"
    }
    retweet_data = multi_page_obtain_data(url, params)
    retweet_user_ids = { entry["id"]: entry["username"] for entry in retweet_data }

    url = "https://api.twitter.com/2/tweets/{}/quote_tweets".format(tweet_id)
    params = {
        "max_results": 100, 
        "expansions": "author_id", 
        "user.fields": "created_at,id,username"
    }
    quote_data = multi_page_obtain_data(url, params, lambda data: data.get("includes", {"users": []}).get("users", []))
    quote_user_ids = { entry["id"]: entry["username"] for entry in quote_data }

    retweet_user_ids.update(quote_user_ids)
    with open("retweets.temp", "w") as f:
        for entry in retweet_user_ids:
            f.write(str(entry) + "\n")   
    print("Step 2: fetch retweets done. Detailed results are in retweets.temp")

    return retweet_user_ids

def fetch_comments():
    url = "https://api.twitter.com/2/tweets/search/recent?query=quotes_of_tweet_id:{}".format(tweet_id)
    params = {
        "max_results": 100, 
        "tweet.fields": "author_id"
    }
    data = multi_page_obtain_data(url, params)

    url = "https://api.twitter.com/2/tweets/search/recent?query=conversation_id:{}".format(tweet_id)
    params = {
        "max_results": 100, 
        "tweet.fields": "author_id"
    }
    data += multi_page_obtain_data(url, params)

    with open("conver.temp", "w") as f:
        for entry in data:
            f.write(str(entry) + "\n")

    print("Step 3: fetch conversation done. Detailed results are in conver.temp")


    comment_per_user = defaultdict(str)
    for entry in data:
        comment_per_user[entry["author_id"]] += entry["text"]
    return comment_per_user

def parse_comments(comment_per_user, participant_ids, follower_ids_and_names):
    data = []
    w3 = Web3(Web3.HTTPProvider(network_url))
    ns = ENS.from_web3(w3)
    for participant_id in participant_ids:
        comment = comment_per_user[participant_id]
        wallet = "invalid"
        try:
            index = comment.index(comment_prefix)
            wallet = comment[index:index+42]
        except ValueError:
            web3_name = ""
            tokens = comment.split(" ")
            for token in tokens:
                if eth_suffix in token:
                    web3_name = token
            try:
                wallet = ns.address(web3_name)
                if wallet is None:
                    print(f"Failed to convert {comment} to an address")
            except Exception as e:
                print(f"Failed to convert {comment} to an address: {e}")
                continue
        if not Web3.is_address(wallet):
            continue
        data.append({
            "id": participant_id,
            "username": follower_ids_and_names.get(participant_id, "USERNAME_MISSING"),
            "wallet": Web3.to_checksum_address(wallet)
            })

    with open("wallets.temp", "w") as f:
        for entry in data:
            f.write(json.dumps(entry) + "\n")

    print("Step 4: wallet parsing done. Confirm results in wallets.temp before proceeding to mint: ")

def main(skip_followers):
    follower_ids_and_names = {}
    if skip_followers:
        # Fetch all retweets from a tweet
        follower_ids_and_names = fetch_users_from_retweets()
        participant_ids = set(follower_ids_and_names.keys())
    else:
        # Fetch followers of the account
        follower_ids_and_names = fetch_followers()
        participant_ids = set(follower_ids_and_names.keys())
        # Fetch all retweets from a tweet
        participant_ids = participant_ids.intersection(fetch_users_from_retweets().keys())
    # Fetch comments of a tweet
    comment_per_user = fetch_comments()
    # join all 3 user groups for intersection
    participant_ids = participant_ids.intersection(comment_per_user.keys())
    # fetch all comments that meet the criteria, parse wallet addresses
    data_per_wallet = parse_comments(comment_per_user, participant_ids, follower_ids_and_names)


if __name__ == "__main__":
    skip_followers = False
    if len(sys.argv) > 1:
        skip_followers = bool(sys.argv[1])
    main(skip_followers)
