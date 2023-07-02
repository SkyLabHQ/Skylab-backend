import requests
import json
import sys
from web3 import Web3

# Active tournament tweet: CHANGE THIS
tweet_id = "1672419123299749890"

# Twitter APP settings
bearer_token = "AAAAAAAAAAAAAAAAAAAAAHTNoQEAAAAA162K7w7ePmv1cQtqx438Xr2i4Y8%3DXamvvRacTOsEBM8vnkKU0fsrXKOnOFaBWN3fhyZaGVfGjBbbtV"
# Twitter account id
account_id = "1499603237959192577"

# Comment matching
comment_prefix = "0x"

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

def multi_page_obtain_data(url, params):
    data = []
    resp_data = get(url, params)

    while "meta" in resp_data and resp_data["meta"]["result_count"] > 0:
        data += resp_data["data"]
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
    retweet_user_ids = set(entry["id"] for entry in retweet_data)

    url = "https://api.twitter.com/2/tweets/{}/quote_tweets".format(tweet_id)
    params = {
        "max_results": 100, 
        "expansions": "author_id"
    }
    quote_data = multi_page_obtain_data(url, params)
    quote_user_ids = set(entry["author_id"] for entry in quote_data)

    data = retweet_data + quote_data
    with open("retweets.temp", "w") as f:
        for entry in data:
            f.write(str(entry) + "\n")   
    print("Step 2: fetch retweets done. Detailed results are in retweets.temp")

    return retweet_user_ids.union(quote_user_ids)

def fetch_comments():
    url = "https://api.twitter.com/2/tweets/search/recent?query=conversation_id:{}".format(tweet_id)
    params = {
        "max_results": 100, 
        "tweet.fields": "author_id"
    }
    data = multi_page_obtain_data(url, params)

    url = "https://api.twitter.com/2/tweets/search/recent?query=quotes_of_tweet_id:{}".format(tweet_id)
    params = {
        "max_results": 100, 
        "tweet.fields": "author_id"
    }
    data += multi_page_obtain_data(url, params)

    with open("conver.temp", "w") as f:
        for entry in data:
            f.write(str(entry) + "\n")

    print("Step 3: fetch conversation done. Detailed results are in conver.temp")

    return {entry["author_id"]: entry["text"] for entry in data}

def parse_comments(comment_per_user, participant_ids, follower_ids_and_names):
    data = []
    for participant_id in participant_ids:
        comment = comment_per_user[participant_id]
        try:
            index = comment.index(comment_prefix)
        except ValueError:
            continue
        wallet = comment[index:index+42]
        if not Web3.is_address(wallet):
            continue
        data.append({
            "id": participant_id,
            "username": follower_ids_and_names.get(participant_id, "USERNAME_MISSING"),
            "wallet": wallet
            })

    with open("wallets.temp", "w") as f:
        for entry in data:
            f.write(json.dumps(entry) + "\n")

    print("Step 4: wallet parsing done. Confirm results in wallets.temp before proceeding to mint: ")

def main(skip_followers):
    follower_ids_and_names = {}
    if skip_followers:
        # Fetch all retweets from a tweet
        participant_ids = fetch_users_from_retweets()
    else:
        # Fetch followers of the account
        follower_ids_and_names = fetch_followers()
        participant_ids = set(follower_ids_and_names.keys())
        # Fetch all retweets from a tweet
        participant_ids = participant_ids.intersection(fetch_users_from_retweets())
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
