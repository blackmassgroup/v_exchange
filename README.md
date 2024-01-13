# VExchange

## Features

- [LiveView Authentication](https://fly.io/phoenix-files/phx-gen-auth/)
- User Role and Permission system
- Direct to S3/Wasabi upload with LiveView
  - https://hexdocs.pm/phoenix_live_view/uploads-external.html
- Generates presigned urls for secure download
- Calculates file hashes with [`:crypto.hash/2`](https://www.erlang.org/doc/man/crypto.html#hash-2)
- ~~Uploads to [Triage](https://tria.ge/) on upload to Vx Underground via [Oban Job Scheduler](https://hexdocs.pm/oban/Oban.html) and notifies the user of completion with `Phoenix.Channels`.~~
- Checks for VT Report on load of the `Sample` show page.
- Uses [`libcluster`](https://fly.io/docs/elixir/the-basics/clustering/#adding-libcluster) and [`fly_postgres`](https://hexdocs.pm/fly_postgres/readme.html) for scalability
- Has [CI/CD](https://fly.io/docs/elixir/advanced-guides/github-actions-elixir-ci-cd/) setup and is deployed on Fly.io.
- ~~Custom Discord Logger backend~~
- Upload, login and get sample API routes

### Built With

- **Postgres**
- **erlang** 
- [**Elixir**](https://hexdocs.pm/elixir/Kernel.html) 
- [**Phoenix**](https://hexdocs.pm/phoenix/Phoenix.html)
- [**Phoenix LiveView**](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
- **NodeJS**
- [**TailwindCSS**](https://tailwindcss.com/docs/installation) 

## Getting Started

### Prerequisites

1. Install `erlang`, `Elixir`, `NodeJS`, `Postgres`

   1. With homebrew the commands are:

   ```zsh
    brew update
    brew install erlang elixir nodejs postgres
   ```

   2. Or if you prefer `asdf`

   ```zsh
    brew update
    brew install asdf

    asdf plugin-add erlang
    asdf plugin-add elixir
    asdf plugin-add nodejs

    asdf install
   ```

### Installation

1.  Clone this Repo and enter the directory.
2.  Set up the project with the command `mix setup`
3.  Set the following env variables in order to get Wasabi/S3 to work.
    1. `AWS_ACCESS_KEY_ID`
    2. `AWS_SECRET_ACCESS_KEY`
    3. `S3_BUCKET_NAME`
4.  Set the following env variables in order to get Triage / VT to work.
    1.  `VIRUS_TOTAL_API_KEY`
    2.  `TRIAGE_API_KEY`
5.  Set the following env variables in order to get Discord Logging to work. (optional)
    1.  `DISCORD_BOT_TOKEN`
    2.  `DISCORD_CHANNEL_ID`
6.  Start Phoenix server with `iex -S mix phx.server`
    1. Now you can visit [`localhost:4000`](http://localhost:4000) or [`localhost:4001`](https://localhost:4001) from your browser.
7.  Once you register a user, you make it admin by running this in the same window you ran `iex -S mix phx.server` in (yes we run commands in a running server)
    1.  `VExchange.Accounts.get_user!(1) |> VExchange.Accounts.add_role_to_user("Admin")`

> You can run unit tests with the command `mix test`

### API Routes

Documentation can be found at [here](https://docs.virus.exchange) and requires an API key generated when a user signs up.

Example script using the upload API to upload all files from a sub directory.

```python
import requests, os, sys
from concurrent.futures import ThreadPoolExecutor

MAX_WORKERS = 10
API_LOGIN = "https://virus.exchange/api/login"
API_UPLOAD = "https://virus.exchange/api/upload"

TOKEN=""
EMAIL="ur email"

if TOKEN == "":
        PASSWORD=input("Enter your password: ")
        r = requests.post(API_LOGIN, data={"email":EMAIL, "password":PASSWORD})
        TOKEN = r.json()["data"]["token"]
 
def process_file(subdir, file):
    filename = os.path.join(subdir, file)
    with open(filename, "rb+") as f:
        file_content = f.read()
        r = requests.post(API_UPLOAD, headers={'Authorization': f"Bearer {TOKEN}", "Content-Type": "application/x-www-form-urlencoded"}, data=file_content)
        print(f"{os.path.basename(filename)}: STATUS({r.status_code}) {r.text}")

def main(directory):
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        for subdir, dirs, files in os.walk(directory):
            for file in files:
                executor.submit(process_file, subdir, file)

if __name__ == '__main__':
    main(sys.argv[1])
```

### TODO

- Setup Minio for Dev upload / download
- Better file types
- YARA Tags 

## Database architecture 🗂

```mermaid
classDiagram
    class Sample{
      +Integer size
      +String md5
      +String sha1
      +String sha256
      +String sha512
      +String s3_object_key
      +Array names
      +Array tags
      +DateTime first_seen
    }

    class Users {
     +String email
     +String username
     +String password
     +Integer role_id
     +String hashed_password
     +DateTime confirmed_at
    }
    class Role {
        +String name
        +Jsonb permissions
    }
```
