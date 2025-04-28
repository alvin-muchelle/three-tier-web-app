resource "null_resource" "send_login_email" {
  depends_on = [aws_sns_topic.login_topic]

  provisioner "local-exec" {
    command = "bash ./send_login_details.sh ${aws_sns_topic.login_topic.arn}"
  }
}
