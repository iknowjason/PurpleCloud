# Create an app to practice consent phishing!  Writes phishing_app.tf.
# This script helps you to automatically and quickly write terraform
# From there you can customize your terraform further and create your own templates!
# Author:  Jason Ostrom
import os.path
import argparse

# Jinaj2 Templates for the Templates themselves.
from jinja2 import Environment, FileSystemLoader

# argparser stuff
parser = argparse.ArgumentParser(description='A script to create terraform for a consent phishing app')

# Add argument for application display name 
parser.add_argument('-n', '--name', dest='name')

# Add argument for redirect_uris 
parser.add_argument('-re', '--redirect_uris', dest='redirect_uris')

# Add argument for homepage_url 
parser.add_argument('-ho', '--homepage_url', dest='homepage_url')

# Add argument for logout_url 
parser.add_argument('-lo', '--logout_url', dest='logout_url')

# parse arguments
args = parser.parse_args()

# Azure phishing app terraform file
tapp_file = "phishing_app.tf"

# parse the name if specified
default_name = "Sample App"
if not args.name:
    print("[+] Using default application name: ", default_name)
else:
    default_name = args.name
    print("[+] User supplied application name: ", default_name)

# parse the redirect_uris if specified 
default_redirect_uris = "http://localhost:30662/gettoken" 
if not args.redirect_uris:
    print("[+] Using default redirect_uris: ", default_redirect_uris)
else:
    default_redirect_uris = args.redirect_uris
    print("[+] User supplied redirect_uris: ", default_redirect_uris)

# parse the homepage_url if specified
default_homepage_url = "https://localhost:30662"
if not args.homepage_url:
    print("[+] Using default homepage_url: ", default_homepage_url)
else:
    default_homepage_url = args.homepage_url
    print("[+] User supplied homepage_url: ", default_homepage_url)

# parse the logout_url if specified
default_logout_url = "https://localhost:30662/logout"
if not args.logout_url:
    print("[+] Using default logout_url: ", default_logout_url)
else:
    default_logout_url = args.logout_url
    print("[+] User supplied logout_url: ", default_logout_url)

# This is a test for using Jinja2
file_loader = FileSystemLoader('templates')
env = Environment(loader=file_loader)

template = env.get_template('phishing_app.jinja')
output = template.render(
  DISPLAY_NAME=default_name,
  REDIRECT_URIS=default_redirect_uris,
  HOMEPAGE_URL=default_homepage_url,
  LOGOUT_URL=default_logout_url
)

# print
print("[+] Creating the phishing app terraform file: ")

with open("phishing_app.tf", "w") as f:
    f.write(output)
 
