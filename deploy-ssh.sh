#!/usr/bin/expect -f

# Script de Deploy usando Expect para automação SSH
# Servidor: 92.113.33.16

set timeout 300
set server_ip "92.113.33.16"
set server_user "fabianosf"
set server_pass "260281xx@"

spawn ssh -o StrictHostKeyChecking=no ${server_user}@${server_ip}

expect {
    "password:" {
        send "${server_pass}\r"
        exp_continue
    }
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    "$ " {
        send "cd /tmp\r"
        expect "$ "
        send "wget -q https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/deploy-automatico.sh || curl -s -o deploy-automatico.sh https://raw.githubusercontent.com/fabianosf/ecoreport-site/main/deploy-automatico.sh\r"
        expect "$ "
        send "chmod +x deploy-automatico.sh\r"
        expect "$ "
        send "./deploy-automatico.sh\r"
        expect {
            "password:" {
                send "${server_pass}\r"
                exp_continue
            }
            "$ " {
                send "exit\r"
            }
        }
    }
}

interact
