# Signature

The purpose of this small testing tool is to validate the signature of the CDN cookie.  

The coookie has the name `Cloud-CDN-Cookie` and the value has the following format:

```
URLPrefix=aHR0YWdlLmJkYi1tYWluLmNvLnVr:Expires=1665682120:KeyName=cdn-signed-url-key:Signature=Ezk6ytp5GJl5j7-Bm4E=
```

You can validate the signature by running the following command:

```shell
go run . --prefix -aHR0YWdlLmJkYi1tYWluLmNvLnVr -expire -1665682120 -keyname cdn-signed-url-key --sig Ezk6ytp5GJl5j7-Bm4E=
```

It will print the result on the command line. 