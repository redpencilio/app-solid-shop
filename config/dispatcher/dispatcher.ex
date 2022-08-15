defmodule Dispatcher do
  use Matcher
  define_accept_types [
    html: [ "text/html", "application/xhtml+html" ],
    json: [ "application/json", "application/vnd.api+json" ],
    img: [ "image/jpg", "image/jpeg", "image/png" ],
  ]

  @any %{}
  @json %{ accept: %{ json: true } }
  @html %{ accept: %{ html: true } }

  # In order to forward the 'themes' resource to the
  # resource service, use the following forward rule:
  #
  # match "/themes/*path", @json do
  #   Proxy.forward conn, path, "http://resource/themes/"
  # end
  #
  # Run `docker-compose restart dispatcher` after updating
  # this file.

  match "/sync/*path", @json do
    Proxy.forward conn, path, "http://search/sync/"
  end

  match "/query/*path", @json do
    Proxy.forward conn, path, "http://search/query/"
  end

  match "/buy/*path", @json do
    Proxy.forward conn, path, "http://order/buy/"
  end

  match "/sales/*path", @json do
    Proxy.forward conn, path, "http://order/sales/"
  end

  match "/purchases/*path", @json do
    Proxy.forward conn, path, "http://order/purchases/"
  end

  match "/payments/*path" do
    Proxy.forward conn, path, "http://payments/payments/"
  end

  get "/search/*path", @json do
    Proxy.forward conn, path, "http://mu-search/"
  end

  match "/profile/*path", @json do
    Proxy.forward conn, path, "http://search/profile/"
  end

  match "/auth/*path", @json do
    Proxy.forward conn, path, "http://search/auth/"
  end

  post "/files/*path", %{ accept: %{ img: true, json: true } } do
    Proxy.forward conn, path, "http://file/files/"
  end

  get "/files/*path", %{ accept: %{ img: true, json: true } } do
    Proxy.forward conn, path, "http://file/files/"
  end
  # no delete method supported because otherwise everyone could delete all files.

  match "/*_", %{ last_call: true } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end
end
