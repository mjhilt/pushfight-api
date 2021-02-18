port module Api exposing (Cred, username, login, logout, credDecoder, storeCredWith)

{-| This module is responsible for communicating to the Conduit API.
It exposes an opaque Endpoint type which is guaranteed to point to the correct URL.
-}

import Api.Endpoint as Endpoint exposing (Endpoint, get, post)
import Avatar exposing (Avatar)
import Browser
import Browser.Navigation as Nav
import Http exposing (Body, Expect)
import Json.Decode as Decode exposing (Decoder, Value, decodeString, field, string)
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Json.Encode as Encode
import Url exposing (Url)
import Username exposing (Username)



-- CRED


{-| The authentication credentials for the Viewer (that is, the currently logged-in user.)
This includes:
  - The cred's Username
  - The cred's authentication token
By design, there is no way to access the token directly as a String.
It can be encoded for persistence, and it can be added to a header
to a HttpBuilder for a request, but that's it.
This token should never be rendered to the end user, and with this API, it
can't be!
-}
type Cred
    = Cred Username String


username : Cred -> Username
username (Cred val _) =
    val


credHeader : Cred -> Http.Header
credHeader (Cred _ str) =
    Http.header "authorization" ("Token " ++ str)


{-| It's important that this is never exposed!
We expose `login` and `application` instead, so we can be certain that if anyone
ever has access to a `Cred` value, it came from either the login API endpoint
or was passed in via flags.
-}
credDecoder : Decoder Cred
credDecoder =
    Decode.succeed Cred
        |> required "username" Username.decoder
        |> required "token" Decode.string



-- PERSISTENCE


decode : Decoder (Cred -> a) -> Value -> Result Decode.Error a
decode decoder value =
    -- It's stored in localStorage as a JSON String;
    -- first decode the Value as a String, then
    -- decode that String as JSON.
    Decode.decodeValue Decode.string value
        |> Result.andThen (\str -> Decode.decodeString (Decode.field "user" (decoderFromCred decoder)) str)


port onStoreChange : (Value -> msg) -> Sub msg


credChanges : (Maybe Cred -> msg) -> Sub msg
credChanges toMsg =
    onStoreChange (\value -> toMsg (Decode.decodeValue credDecoder value |> Result.toMaybe ) )
--viewerChanges : (Maybe Cred -> msg) -> Decoder Cred -> Sub msg
--viewerChanges toMsg decoder =
--    --onStoreChange
--    onStoreChange (\value -> toMsg (decodeFromChange decoder value))


--decodeFromChange : Decoder (Cred -> viewer) -> Value -> Maybe viewer
--decodeFromChange viewerDecoder val =
--    -- It's stored in localStorage as a JSON String;
--    -- first decode the Value as a String, then
--    -- decode that String as JSON.
--    Decode.decodeValue (storageDecoder viewerDecoder) val
--        |> Result.toMaybe


storeCredWith : Cred -> Cmd msg
storeCredWith (Cred uname token) =
    let
        json =
            Encode.object
                [ ( "user"
                  , Encode.object
                        [ ( "username", Username.encode uname )
                        , ( "token", Encode.string token )
                        ]
                  )
                ]
    in
    storeCache (Just json)


logout : Cmd msg
logout =
    storeCache Nothing


login : Http.Body -> Decoder (Cred -> String) -> ((Result Http.Error String) -> msg) -> Cmd msg
login body decoder msg =
    post Endpoint.login body ( Http.expectJson msg (Decode.field "user" (decoderFromCred decoder)))

register : Http.Body -> Decoder (Cred -> String) -> ((Result Http.Error String) -> msg) -> Cmd msg
register body decoder msg =
    post Endpoint.register body ( Http.expectJson msg (Decode.field "user" (decoderFromCred decoder)))

port storeCache : Maybe Value -> Cmd msg



-- SERIALIZATION
-- APPLICATION


--application :
--    Decoder (Cred -> viewer)
--    ->
--        { init : Maybe viewer -> Url -> Nav.Key -> ( model, Cmd msg )
--        , onUrlChange : Url -> msg
--        , onUrlRequest : Browser.UrlRequest -> msg
--        , subscriptions : model -> Sub msg
--        , update : msg -> model -> ( model, Cmd msg )
--        , view : model -> Browser.Document msg
--        }
--    -> Program Value model msg
--application viewerDecoder config =
--    let
--        init flags url navKey =
--            let
--                maybeViewer =
--                    Decode.decodeValue Decode.string flags
--                        |> Result.andThen (Decode.decodeString (storageDecoder viewerDecoder))
--                        |> Result.toMaybe
--            in
--            config.init maybeViewer url navKey
--    in
--    Browser.application
--        { init = init
--        , onUrlChange = config.onUrlChange
--        , onUrlRequest = config.onUrlRequest
--        , subscriptions = config.subscriptions
--        , update = config.update
--        , view = config.view
--        }


--storageDecoder : Decoder (Cred -> viewer) -> Decoder viewer
--storageDecoder viewerDecoder =
--    Decode.field "user" (decoderFromCred viewerDecoder)


--login : Http.Body -> Decoder (Cred -> a) -> Cmd a
--login body decoder =
--    post Endpoint.login Nothing body (Decode.field "user" (decoderFromCred decoder))


--register : Http.Body -> Decoder (Cred -> a) -> Cmd a
--register body decoder =
--    post Endpoint.users Nothing body (Decode.field "user" (decoderFromCred decoder))


--settings : Cred -> Http.Body -> Decoder (Cred -> a) -> Cmd a
--settings cred body decoder =
--    post Endpoint.user cred body (Decode.field "user" (decoderFromCred decoder))


decoderFromCred : Decoder (Cred -> a) -> Decoder a
decoderFromCred decoder =
    Decode.map2 (\fromCred cred -> fromCred cred)
        decoder
        credDecoder



-- ERRORS


addServerError : List String -> List String
addServerError list =
    "Server error" :: list


--{-| Many API endpoints include an "errors" field in their BadStatus responses.
---}
--decodeErrors : Http.Error -> List String
--decodeErrors error =
--    case error of
--        Http.BadStatus response ->
--            response.body
--                |> decodeString (field "errors" errorsDecoder)
--                |> Result.withDefault [ "Server error" ]

--        err ->
--            [ "Server error" ]


--errorsDecoder : Decoder (List String)
--errorsDecoder =
--    Decode.keyValuePairs (Decode.list Decode.string)
--        |> Decode.map (List.concatMap fromPair)


fromPair : ( String, List String ) -> List String
fromPair ( field, errors ) =
    List.map (\error -> field ++ " " ++ error) errors



---- LOCALSTORAGE KEYS


--cacheStorageKey : String
--cacheStorageKey =
--    "cache"


--credStorageKey : String
--credStorageKey =
--    "cred"
