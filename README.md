# seminar_wordpress
script and cloudformation template used in seminar

# Script

`userdata.sh`

WordPressのセットアップをするスクリプト。EC2作成時のUserdataに使用。
以下の変数を実環境に設定して使用。

- DB_HOST=${RDSのエンドポイント}
- DB_USER=${RDSのマスターユーザー名（このユーザーの権限でwordpressのデータベース,ユーザーを作成していく）}
- DB_PASSWORD=${上記RDSマスターユーザーのパスワード}

# CloudFormation template

`wordpress_stack.yml`

セミナーで作成した構成（VPC,ELB,EC2,RDS）を作成するCloudFormationのテンプレート
以下のパラメータについては環境に合わせて変更してあげる必要がある

- SshKey: AWSに登録しているSSH鍵の名前。EC2インスタンス作成時に、この鍵でログインできるようにAWSが設定してくれる。 `ssh ec2-user@${EC2のIPアドレス} -i ${SSH鍵へのパス}`
