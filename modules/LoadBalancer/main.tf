resource "aws_lb" "application_load_balancer" {
  name               = "application-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.instances.id]
  subnets            = data.aws_subnets.default_subnets.ids
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "instances_target_group" {
  name     = "instances-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id
}

resource "aws_lb_target_group_attachment" "instance_1_attachment" {
  target_group_arn = aws_lb_target_group.instances_target_group.arn
  target_id        = aws_instance.instance-1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "instance_2_attachment" {
  target_group_arn = aws_lb_target_group.instances_target_group.arn
  target_id        = aws_instance.instance-2.id
  port             = 8080
}