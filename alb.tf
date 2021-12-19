
# TODO: 
# 1. improve security by using protocal HTTPS over port 443, in combination AWS 
# Certificate Manager (ACM). ACM provisions and manages certificates. 

# Provision ALB
resource "aws_alb" "alb" {
  name = "application-load-balancer"
  subnets = aws_subnet.public.*.id
  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = "alb"
  }
}

# Assign port to keep an ear out for incoming traffic. Redirect traffic from 
# the ALB to the target group. 
resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.id
  port = var.app_port
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.target_group.id
    type = "forward"
  }
}

#resource "aws_alb_listener_rule" "admin" {
#  depends_on = ["aws_alb_target_group.target_group"]  
#  listener_arn = "${aws_alb_listener.alb_listener.arn}"  
#  priority = var.priority   
#  
#  action {    
#    type = "forward"    
#    target_group_arn = aws_alb_target_group.target_group.id  
#  }
#   
#  condition {    
#    field = "path-pattern"    
#    values = "/admin"  # should be variable  
#  }
#}

# Set target for listner
resource "aws_alb_target_group" "target_group" {
  name = "target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc_dev.id
  target_type = "ip"

  health_check {
    healthy_threshold = "3"
    interval = "30"
    protocol = "HTTP"
    matcher = "200"
    timeout = "3"
    path = var.health_check_path
    unhealthy_threshold = "2"
  }
}
