Specify an SSH Key
------------------

If you need to install dependencies stored in private repositories, but you don't want to hardcode passwords in the code,
you can use the following approach.


- Generate or use an existing a new SSH key pair (https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)

  For this example, assume that you named the key `deploy_key`.

- Add the public ssh key to your private repository account.

  * Github: https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

  * Bitbucket: https://confluence.atlassian.com/bitbucket/add-an-ssh-key-to-an-account-302811853.html

- Add CUSTOM_SSH_KEY and CUSTOM_SSH_KEY_HOSTS environment variables to you heroku app

  * CUSTOM_SSH_KEY must be base64 encoded
  * CUSTOM_SSH_KEY_HOSTS is a comma separated list of the hosts that will use the custom SSH key

  ```
  # OSX
  $ heroku config:set CUSTOM_SSH_KEY=$(base64 --input ~/.ssh/deploy_key.pub) CUSTOM_SSH_KEY_HOSTS=bitbucket.org,github.com

  # Linux
  $ heroku config:set CUSTOM_SSH_KEY=$(base64 ~/.ssh/deploy_key.pub | tr -d '\n') CUSTOM_SSH_KEY_HOSTS=bitbucket.org,github.com
  ```

- Deploy your app and enjoy!
