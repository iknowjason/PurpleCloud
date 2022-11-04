# Phishing Application 

```$ python3 phishing_app.py --name <DISPLAY_NAME> --redirect_uri <REDIRECT_URI> ```

This generates a terraform format HCL file for ```phishing_app.tf```.

**Example 1:**
```
python3 phishing_app.py
```

**Example 2:**
```
python3 phishing_app.py --name EvilApp --redirect_uri https://www.evil-app.com/get_token 
```

### Important Note
This generator lives in the ```generators/phishing_app``` directory.  Navigate into this directory first.
```
cd generators/phishing_app
```

The following Graph API delegated scope permissions are automatically created for the application:
```
Contacts.Read
Mail.Read
Mail.Send
Files.Read
Files.Read.All
Files.ReadWrite.All
User.Read
```

API permissions can be customized by adding the ```id``` for the correct permission, as shown in the code block below:
```
    resource_access {
      id   = "570282fd-fa5c-430d-a7fd-fc8dc98a9dca" #  Mail.Read
      type = "Scope"
    }
```

## Full command line parameters
```--name <DISPLAY_NAME>```:  Specify the display name for the application (Default: Sample App)

```--redirect_uri <REDIRECT_URI>```:  The redirect uri that the application uses to receive OAuth tokens.
(Default: "http://localhost:30662/gettoken")

```--homepage_url <HOMEPAGE_URL>```:  The homepage URL used by the application.
(Default: "https://localhost:30662")

```--logout_url <LOGOUT_URL>```:  The logout URL used by the application.
(Default: "https://localhost:30662/logout")

## Demo
A video demonstration of building an application consent phishing  lab with options and illustrations.

[![App Consent Phishing Demo]()](https://youtu.be/o9wb6aux9Rk "application consent phishing lab")
