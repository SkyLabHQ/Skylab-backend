import os
from requests_oauthlib import OAuth1Session
from flask import Flask, redirect, request, session, url_for
from dotenv import load_dotenv

load_dotenv()
app = Flask(__name__)
app.secret_key = 'super secret key'

api_key = os.getenv("TWITTER_API_KEY")
api_secret = os.getenv("TWITTER_API_SECRET")
callback_url = "http://127.0.0.1:5000/callback"

@app.route('/')
def start_oauth():
    oauth = OAuth1Session(api_key, client_secret=api_secret, callback_uri=callback_url)
    request_token_url = "https://api.twitter.com/oauth/request_token"
    fetch_response = oauth.fetch_request_token(request_token_url)

    session['resource_owner_key'] = fetch_response.get('oauth_token')
    session['resource_owner_secret'] = fetch_response.get('oauth_token_secret')

    authorization_url = oauth.authorization_url("https://api.twitter.com/oauth/authorize")
    return redirect(authorization_url)

@app.route('/callback')
def callback():
    resource_owner_key = session['resource_owner_key']
    resource_owner_secret = session['resource_owner_secret']

    oauth_response = request.args
    verifier = oauth_response.get('oauth_verifier')

    oauth = OAuth1Session(api_key,
                          client_secret=api_secret,
                          resource_owner_key=resource_owner_key,
                          resource_owner_secret=resource_owner_secret,
                          verifier=verifier)

    access_token_url = "https://api.twitter.com/oauth/access_token"
    oauth_tokens = oauth.fetch_access_token(access_token_url)

    session['access_token'] = oauth_tokens['oauth_token']
    session['access_token_secret'] = oauth_tokens['oauth_token_secret']

    return redirect(url_for('tweet'))

@app.route('/tweet')
def tweet():
    access_token = session['access_token']
    access_token_secret = session['access_token_secret']

    oauth = OAuth1Session(api_key,
                          client_secret=api_secret,
                          resource_owner_key=access_token,
                          resource_owner_secret=access_token_secret)

    tweet_text = "Hello from Twitter API v2 with Flask!"
    post_tweet_url = "https://api.twitter.com/2/tweets"
    response = oauth.post(post_tweet_url, json={"text": tweet_text})

    if response.status_code == 201:
        return "Tweet sent successfully!"
    else:
        return f"Failed to send tweet: {response.status_code} - {response.text}"

if __name__ == '__main__':
    app.run(debug=True)