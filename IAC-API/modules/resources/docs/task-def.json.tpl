[
    {
        "essential": true,
        "name": "${name}",
        "image": "${image}",
        "portMapping": [
            {
                "hostPort": ${port},
                "cantainerPort": ${port},
                "protocol": "tcp"
            }
        ],
        "environment": [
            {
                "name": "${var1Name}",
                "value": "${var1Value}"
            },
            {
                "name": "${var2Name}",
                "value": "${var2Value}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${awslogs-group}",
                "awslogs-region": "${awslogs-region}",
                "awslogs-stream-prefix": "${awslogs-stream-prefix}"
            }
        }
    }
]