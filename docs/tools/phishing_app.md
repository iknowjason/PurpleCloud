# Phishing Application 

```$ python3 phishing_app.py --name <DISPLAY_NAME> --redirect_uri <REDIRECT_URI> ```

This generates a terraform format HCL file for ```phishing_app.tf```.

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
