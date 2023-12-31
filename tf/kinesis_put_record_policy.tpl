{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
         ],
         "Resource":[
            "${bucket_arn}",
            "${bucket_arn}/*"
         ]
      },
      {
         "Effect":"Allow",
         "Action":[
            "kinesis:DescribeStream",
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:ListShards",
            "kinesis:PutRecord",
            "kinesis:PutRecords"
         ],
         "Resource":"${stream_arn}"
      }
   ]
}