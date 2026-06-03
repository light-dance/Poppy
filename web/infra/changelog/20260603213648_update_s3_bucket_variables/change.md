---
created: '2026-06-03T21:36:48.722Z'
title: 'Update S3 Bucket Variables'
description: 'Add the Railway variables for the bucket'
service: 'Railway'
---

## Instructions

- In Railway, web service, Variables, add S3 variables:

```
S3_ACCESS_KEY_ID="${{releases.ACCESS_KEY_ID}}"
S3_BUCKET="${{releases.BUCKET}}"
S3_ENDPOINT="${{releases.ENDPOINT}}"
S3_REGION="${{releases.REGION}}"
S3_SECRET_ACCESS_KEY="${{releases.SECRET_ACCESS_KEY}}"
```

## Explanation

- Required to allow app to connect to the Railway bucket
