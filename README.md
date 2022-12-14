# app-solid-shop

The Solid Shop is a user-powered shopping ecosystem by use of SOLID PODs. This brings all parts together.

## Running / Development

* Extra steps related to the payment service provider Mollie for the [mollie-payment-service](https://github.com/madnificent/mollie-payment-service).
    * [Install ngrok](https://ngrok.com/download)
    * `ngrok http 4200` to start ngrok so Mollie can reach your dev setup of [frontend-solid-shop](https://github.com/redpencilio/frontend-solid-shop).
    * Change the `MOLLIE_REDIRECT_URL` and `MOLLIE_BASE_WEBHOOK_URL` in the `docker-compose.yml` to match the ngrok urls
    * Change the `ESS_CLIENT_ID`, `ESS_CLIENT_SECRET` and `ESS_IDP` in the `docker-compose.yml`, see "Setup ESS" below for more information
    * Sign up at [Mollie](https://www.mollie.com/) and get your [API key](https://docs.mollie.com/overview/authentication)
    * (At the end, fill in your API key via the profile page and/or the `MOLLIE_API_KEY` environment variable, see "Mollie API Key" below for more information)
* `docker-compose up -d` to start the related services

When developing, you might want to directly have the changes in the services available in your local stack.
To do this, you can create a `docker-compose.override.yml` file and put the changes in there.
An example on how to do this is shown below.

```yaml
  # This will automatically detect changes and restart the service
  order:
    image: semtech/mu-javascript-template
    volumes:
      - ../solid-shop-order-service/:/app/:cached
  # This will build the image from the local source, use `docker-compose build` together with `docker-compose up -d` to restart the service
  payments:
    build:
      context: ../mollie-payment-service
      dockerfile: Dockerfile
```

## Used services
- [frontend-solid-shop](https://github.com/redpencilio/frontend-solid-shop): The frontend of the Solid Shop
- [solid-shop-order-service](https://github.com/redpencilio/solid-shop-order-service): The order service of the Solid Shop, functions quite like the backend of the Solid Shop
- [solid-sync-service](https://github.com/redpencilio/solid-sync-service): Synchronize data between the user's Solid PODs and the triple store
- [mollie-payment-service](https://github.com/madnificent/mollie-payment-service): Handles the payments of the Solid Shop via Mollie
- [mu-search](https://github.com/mu-semtech/mu-search): Provides fuzzy search for the offerings in the Solid Shop
- [mu-search-elastic-backend](https://github.com/mu-semtech/mu-search-elastic-backend): The Elasticsearch backend of the mu-search service
- [delta-notifier](https://github.com/mu-semtech/delta-notifier): Notifies the Solid Shop about changes in the triple store, used for e.g. the tasks and the search
- [file-service](https://github.com/mu-semtech/file-service): Handles the image uploads on product creation and update
- [docker-virtuoso](https://github.com/redpencilio/docker-virtuoso): The virtuoso service for the triple store, where the Solid Shop data is stored
- [mu-authorization](https://github.com/mu-semtech/mu-authorization): Provides authorization for the Solid Shop, so not everyone can e.g. access the secret keys and other information
- [mu-identifier](https://github.com/mu-semtech/mu-identifier): Handles session identification
- [mu-dispatcher](https://github.com/mu-semtech/mu-dispatcher): Dispatches requests to the right microservices

## Contribution

We make use of [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

When making changes to a pull request, we prefer to update the existing commits with a rebase instead of appending new commits.

The project board of this project can be found [here](https://project.redpencil.io/project/solid-webshop/kanban).

Questions? Join our Matrix room [#solid-shop](https://matrix.to/#/!dzdBEfBtjWRNytDgoP:chat.semantic.works).

## Payments flow

Below, the payments flow and communication between the frontend and the different services is specified.
- **frontend ---> order**
    - initiate order, send back `orderId`
- **order ---> sync**
  - *via task*
  - send `orderId` as `ext:order` triple
  - query triple store and accordingly update user PODs
- **frontend ---> payment**
  - *location rewrite: user goes to payment service*
  - send `orderId`, initiate payment, save payment info to triple store
- **payment ---> mollie**
  - *location rewrite: user goes to Mollie checkout page to pay*
  - handle payment
- **mollie ---> frontend**
  - *location rewrite: user goes back to application frontend*
  - go to redirect url
- **mollie ---> payment**
  - call callback url (sends `orderId`), update payment info in triple store (add `paymentId`, update `orderStatus`) by querying Mollie API
- **payment ---> order**
  - gives the chance to do extra stuff, and sends a task to the sync service to update the user PODs
- **order ---> sync**
  - *via task*
  - send `orderId` as `ext:order` triple
  - query triple store and accordingly update buyer and seller PODs

### Mollie API Key

You can specify the application's Mollie API key via the `MOLLIE_API_KEY` environment variable in the `docker-compose.yml` file.  
It will use this API key to handle payments if there is no Mollie API key specified for the seller in the triple store.  
However, specifying a Mollie API key for the seller in the triple store (`?sellerWebId ext:mollieApiKey ?mollieApiKey`) will override the default API key, letting the buyer directly pay to the seller.

### Tasks

The Solid Shop uses the [solid-sync-service](https://github.com/redpencilio/solid-sync-service) to update the user PODs.
To let the Solid Sync Service know what and when to update, it sends a task via the [delta-notifier](https://github.com/mu-semtech/delta-notifier).

The used tasks in the Solid Shop are described as follows:
```
?task a ext:Task;
    ext:taskType ?taskType;
    ext:dataFlow ?dataFlow;
    ext:taskStatus "pending".
OPTIONAL { ?task ext:order ?orderId. }  # in case the task is related to an order creation or update, ?dataFlow = "DbToPod"
OPTIONAL { ?task ext:pod ?pod; ext:webId ?webId. }  # in case the task is related to a DB update, ?dataFlow = "PodToDb"
VALUES ?taskType { ext:SavedOrderTask ext:UpdatedOrderTask ext:SyncOfferingsTask }
```

## Authentication flow

To be able to read and write to the specific resources in the user's POD, authentication and permissions to those resources are required.
As there is no Solid spec for this yet at the time of writing, non-spec behavior is used from the supported servers.

### CSS

[Non-spec behavior of CSS.](https://communitysolidserver.github.io/CommunitySolidServer/4.0/client-credentials/)

To authenticate once:
- **user ---> frontend**
    - enters `email`, `password` and `IDP URL`
- **frontend ---> CSS IDP**
    - sends `email`, `password` and `name='solid-shop'` to the CSS IDP at `${IDPURL}/idp/credentials`
    - generates a token
    - sends back the client id and client secret
- **frontend ---> sync**
    - sends `clientWebId`, `clientId`, `clientSecret`, `idpUrl` and `idpType='css'` to the solid-sync-service at `/auth/credentials`
    - saves the credentials to the triple store

On reading from or writing to the user's POD:
- **sync ---> CSS IDP**
    - sends `clientId`, `clientSecret` to the CSS IDP at `${IDPURL}/.oidc/token`
    - requests access token
- **sync ---> user's POD**
    - uses the access token to send authenticated requests to the user's POD

### ESS

Uses [Access Policies: Universal API](https://docs.inrupt.com/developer-tools/javascript/client-libraries/tutorial/manage-access-policies/#change-agent-access) in the frontend and [Authenticate with Statically Registered Client Credentials](https://docs.inrupt.com/developer-tools/javascript/client-libraries/tutorial/authenticate-nodejs-script/#authenticate-with-statically-registered-client-credentials) in the backend.

To authenticate once:
- **user ---> frontend**
    - clicks the `Login` button
- **frontend ---> sync**
    - GET /auth/ess/webId
    - gets the application's ESS WebId which is needed in the next step
- **frontend ---> ESS IDP**
    - sends access requests using the `@inrupt/solid-client` library for the needed resources
- **frontend ---> sync**
    - sends `clientWebId` and `idpType='ess'` to the solid-sync-service at `/auth/credentials`
    - saves the credentials (just `idpType` for ESS) to the triple store

On reading from or writing to the user's POD:
- **sync ---> user's POD**
    - on startup of the solid-sync-service, it will log in and create an authenticated session using the `ESS_CLIENT_ID` and `ESS_CLIENT_SECRET` environment variables which will then be used to send authenticated requests to the user's POD
    - uses the authenticated session to send authenticated requests to the user's POD

#### Setup ESS

To be able to support ESS POD users, you have to register your application with the ESS IDP. You can do this at [Inrupt Application Registration](https://login.inrupt.com/registration.html).  
Then, you should fill in the `ESS_CLIENT_ID` and `ESS_CLIENT_SECRET` environment variables in the `docker-compose.yml` file. Also change the `ESS_IDP` environment variable if you had used another ESS IDP.
