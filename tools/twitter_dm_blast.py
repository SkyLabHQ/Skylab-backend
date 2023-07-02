import base64
import requests
import os
import hashlib
import re
import json
from requests_oauthlib import OAuth2Session

# DM
DM_text = """✨Congratulations!✨
✈️A tournament paper plane 
has been airdropped to you.
🗓️Valid from June 20 to June 30
"""
client_id = "NG1BVUZsMGhvNEhWMnd6eXNHazk6MTpjaQ"
redirect_uri = "https://twitter.com/skylabHQ"

def handle_rate_limit_or_failure(response, expected):
    if response.status_code == 429:
        input("WARNING: Rate limited - give up and move on?")
    elif response.status_code != expected:
        raise Exception(
            "Request returned an error: {} {}".format(
                response.status_code, response.text
            )
        )

def post(url, headers, body):
    print(f"calling {url}")
    response = requests.request("POST", url, headers=headers, json=body)
    handle_rate_limit_or_failure(response, 201)
    return response.json()

def dm(user_ids, access):
    for i in range(0, len(user_ids), 100):
        dm_ids = user_ids[i:i+100]
        print(f"Sending to {dm_ids}")
        url = "https://api.twitter.com/2/dm_conversations"
        request_body = {}
        request_body['message'] = {}
        request_body['message']['text'] = DM_text
        request_body['participant_ids'] = dm_ids
        request_body['conversation_type'] = "Group"

        headers = {
            "Authorization": "Bearer {}".format(access),
            "Content-Type": "application/json",
            "User-Agent": "v2TweetPython"
        }
        post(url, headers, request_body)

def handle_oauth():
    # Set the scopes needed to be granted by the authenticating user.
    scopes = ["dm.read", "dm.write", "tweet.read", "users.read", "offline.access"]

    # Create a code verifier
    code_verifier = base64.urlsafe_b64encode(os.urandom(30)).decode("utf-8")
    code_verifier = re.sub("[^a-zA-Z0-9]+", "", code_verifier)

    # Create a code challenge
    code_challenge = hashlib.sha256(code_verifier.encode("utf-8")).digest()
    code_challenge = base64.urlsafe_b64encode(code_challenge).decode("utf-8")
    code_challenge = code_challenge.replace("=", "")

    # Start an OAuth 2.0 session
    oauth = OAuth2Session(client_id, redirect_uri=redirect_uri, scope=scopes)

    # Create an authorize URL
    auth_url = "https://twitter.com/i/oauth2/authorize"
    authorization_url, state = oauth.authorization_url(
        auth_url, code_challenge=code_challenge, code_challenge_method="S256"
    )

    # Visit the URL to authorize your App to make requests on behalf of a user
    print(
        "Visit the following URL to authorize your App on behalf of your Twitter handle in a browser:"
    )
    print(authorization_url)

    # Paste in your authorize URL to complete the request
    authorization_response = input(
        "Paste in the full URL after you've authorized your App:\n"
    )

    # Fetch your access token
    token_url = "https://api.twitter.com/2/oauth2/token"

    # The following line of code will only work if you are using a type of App that is a public client
    auth = False

    token = oauth.fetch_token(
        token_url=token_url,
        authorization_response=authorization_response,
        auth=auth,
        client_id=client_id,
        include_client_id=True,
        code_verifier=code_verifier,
    )

    # Your access token
    access = token["access_token"]

    return access


def main():
    access = handle_oauth()

    success_mint_ids = []
    with open("successful_mints.temp", "r") as f:
        for line in f.readlines():
            wallet_info = json.loads(line)
            success_mint_ids.append(wallet_info["id"])
    dm(success_mint_ids, access)
    print("All done.")

if __name__ == "__main__":
    main()