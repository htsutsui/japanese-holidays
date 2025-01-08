# Japanese (JP) Holidays #

-   [YAML](jp_holidays.yaml)
-   [JSON](jp_holidays.json)
-   [CSV](jp_holidays.csv)

The data was generated using
[Google Calendar API](https://developers.google.com/calendar/api).
If you want to re-generate, please put your `client_secret.json` file.
You may get your own `client_secret.json` from
<https://console.cloud.google.com/apis/credentials>.

## Feature(s) ##

-   Both Japanese (JA) and English (EN) are included.

## Base Calendar ##

-   [Japanese (JA)](https://calendar.google.com/calendar/embed?src=ja.japanese%23holiday@group.v.calendar.google.com)
    日本の祝日
-   [English (EN)](https://calendar.google.com/calendar/embed?src=en.japanese%23holiday@group.v.calendar.google.com)
    Holidays in Japan

## Other observances ##

The holiday calendar provided by Google includes observances in
addition to public holidays. As a result, these additional observances
have been separated into the following files:

-   [YAML](jp_observances.yaml)
-   [JSON](jp_observances.json)
-   [CSV](jp_observances.csv)

For more details, see [Google Calendar Help](https://support.google.com/calendar/answer/13748345?hl=en).

## Link(s) ##

-   [National Holidays, Cabinet Office, Government of Japan (Japanese)](https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html)

## Notice(s) ##

-   There is no warranty for this code and data.
-   Tested using ruby 3.1.2p20.
