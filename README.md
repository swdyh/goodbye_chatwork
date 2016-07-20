# GoodbyeChatwork

This is Chatwork(chatwork.com) log exporter. This can be used also when you can not use API.

## Installation

    $ gem install goobye_chatwork

## Usage

show chat room list (output: room_id room_name count)

    $ goodbye_chatwork -i example@example.com -p your_password
    11111 chatroom1 24
    11112 chatroom1 42

export specified room's chat logs (chat logs only: -e option)

    $ goodbye_chatwork -i example@example.com -p your_password -e room_id

export specified room's chat logs (chat logs and attachment files: -x option)

    $ goodbye_chatwork -i example@example.com -p your_password -x room_id

export all room's chat logs (chat logs only: -e option)

    $ goodbye_chatwork -i example@example.com -p your_password -e all

export all room's chat logs (chat logs and attachment files: -x option)

    $ goodbye_chatwork -i example@example.com -p your_password -x all

## Information

Copyright (c) 2014 swdyh
MIT License
https://github.com/swdyh/goodbye_chatwork
