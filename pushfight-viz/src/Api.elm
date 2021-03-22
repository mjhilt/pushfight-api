port module Api exposing (Cred, username, login, logout, storeCred, credChanges, register, application, decodeErrors, OpenGame, GameChallenge, GameInfo, challenge, start, opengames, mygames)

import Base64
import Browser
import Browser.Navigation as Nav
import Http exposing (Body, Expect)
import Json.Decode as Decode exposing (Decoder, Value, decodeString, field, string)
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Json.Encode as Encode
import Url exposing (Url)


import Avatar exposing (Avatar)
import Api.Endpoint as Endpoint exposing (Endpoint)
import Pushfight.Color exposing (Color(..))
import Username exposing (Username)


-- CRED

type Cred
    = Cred Username String


username : Cred -> Username
username (Cred val _) =
    val


credHeader : Cred -> Http.Header
credHeader (Cred usr str) =
    let
        uname = Username.toString usr
        basic = uname ++ ":" ++ str |> Base64.encode
    in
    Http.header "Authorization" ( "Basic " ++ basic )


get: Endpoint -> Http.Body -> Maybe Cred -> Http.Expect msg -> Cmd msg
get e body cred expect =
    let
        headers =
            case cred of
                Just c ->
                    [credHeader c]
                Nothing ->
                    []
    in
        Http.request
            { method = "GET"
            , headers = headers
            , url = Endpoint.unwrap e
            , expect = expect
            , body = body
            , timeout = Nothing
            , tracker = Nothing
            }


post: Endpoint -> Http.Body -> Maybe Cred -> Http.Expect msg -> Cmd msg
post e body cred expect =
    let
        headers =
            case cred of
                Just c ->
                    [credHeader c]
                Nothing ->
                    []
    in
        Http.request
            { method = "POST"
            , headers = headers
            , url = Endpoint.unwrap e
            , expect = expect
            , body = body
            , timeout = Nothing
            , tracker = Nothing
            }

-- API

-- logout

logout : Cmd msg
logout =
    storeCache Nothing

-- login

login : Http.Body -> ((Result Http.Error Cred) -> msg) -> Cmd msg
login body msg =
    post Endpoint.login body Nothing (Http.expectJson msg credDecoder)

-- register

register : Http.Body -> ((Result Http.Error Cred) -> msg) -> Cmd msg
register body msg =
    post Endpoint.register body Nothing (Http.expectJson msg credDecoder)

-- opengame

type alias OpenGame =
    { gameId: String
    , opponent: String
    }

opengames: (Result Http.Error (List OpenGame) -> msg) -> Cmd msg
opengames msg =
    get Endpoint.opengames Http.emptyBody Nothing (Http.expectJson msg opengamesDecoder)

opengamesDecoderHelper: Decoder OpenGame
opengamesDecoderHelper =
    Decode.map2 OpenGame
        (field "game" string)
        (field "opponent" string)

opengamesDecoder: Decoder (List OpenGame)
opengamesDecoder =
    field "games" (Decode.list opengamesDecoderHelper)

-- mygames

mygames: (Result Http.Error (List String) -> msg) -> Cred -> Cmd msg
mygames msg cred =
    get Endpoint.mygames Http.emptyBody (Just cred) (Http.expectJson msg mygamesDecoder)


mygamesDecoder: Decoder (List String)
mygamesDecoder =
    field "games" (Decode.list string)

-- challenge (starts a game)

type alias GameChallenge =
    { color: Maybe Color
    , timed: Bool
    , opponent: String
    }

challenge: GameChallenge -> (Result Http.Error GameInfo -> msg) -> Cred -> Cmd msg
challenge gc msg cred =
    let
        body = gc |> encodeChallenge |> Http.jsonBody
    in
        post Endpoint.gameChallenge body (Just cred) (Http.expectJson msg gameDecoder)


encodeChallenge: GameChallenge -> Encode.Value
encodeChallenge gc =
    let
        color =
            case gc.color of
                Just White ->
                    "white"
                Just Black ->
                    "black"
                Nothing ->
                    "random"
    in
        Encode.object
            [ ("color", Encode.string color)
            , ("opponent", Encode.string gc.opponent)
            , ("timed", Encode.bool gc.timed)
            ]

-- start game

type alias GameInfo =
    { color: Color
    , gameId: String
    }

start: GameChallenge -> (Result Http.Error GameInfo -> msg) -> Cred -> Cmd msg
start gc msg cred =
    let
        body = gc |> encodeGameStart |> Http.jsonBody
    in
        post Endpoint.gameStart body (Just cred) (Http.expectJson msg gameDecoder)


encodeGameStart: GameChallenge -> Encode.Value
encodeGameStart gc =
    let
        color =
            case gc.color of
                Just White ->
                    "white"
                Just Black ->
                    "black"
                Nothing ->
                    "random"
    in
        Encode.object
            [ ("color", Encode.string color)
            , ("timed", Encode.bool gc.timed)
            ]


-- TODO actually decode pushfight & timer state
gameDecoder: Decoder GameInfo
gameDecoder =
    Decode.map2 GameInfo
        (field "color" (Decode.map parseColor string))
        (field "game" string)

parseColor: String -> Color
parseColor color =
    case color of
        "white" ->
            White
        "black" ->
            Black
        _ ->
            White

-- join game

join: String -> (Result Http.Error GameInfo -> msg) -> Cred -> Cmd msg
join gid msg cred =
    let
        body = Encode.object [("game", Encode.string gid)] |> Http.jsonBody
    in
        post Endpoint.gameJoin body (Just cred) (Http.expectJson msg gameDecoder)


-- PERSISTENCE


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




port onStoreChange : (Value -> msg) -> Sub msg


credChanges : (Maybe Cred -> msg) -> Sub msg
credChanges toMsg =
    onStoreChange (\value -> toMsg (Decode.decodeValue credDecoder value |> Result.toMaybe ) )


port storeCache : Maybe Value -> Cmd msg

storeCred : Cred -> Cmd msg
storeCred (Cred uname token) =
    let
        json =
            Encode.object
                [ ( "username", Username.encode uname )
                , ( "token", Encode.string token )
                ]


    in
    storeCache (Just json)


-- APPLICATION

application :
        { init : Maybe Cred -> Url -> Nav.Key -> ( model, Cmd msg )
        , onUrlChange : Url -> msg
        , onUrlRequest : Browser.UrlRequest -> msg
        , subscriptions : model -> Sub msg
        , update : msg -> model -> ( model, Cmd msg )
        , view : model -> Browser.Document msg
        }
    -> Program Value model msg
application config =
    let
        init flags url navKey =
            let
                maybeCred =
                    Decode.decodeValue Decode.string flags
                        |> Result.andThen (Decode.decodeString credDecoder)
                        |> Result.toMaybe
            in
            config.init maybeCred url navKey
    in
    Browser.application
        { init = init
        , onUrlChange = config.onUrlChange
        , onUrlRequest = config.onUrlRequest
        , subscriptions = config.subscriptions
        , update = config.update
        , view = config.view
        }


decoderFromCred : Decoder (Cred -> a) -> Decoder a
decoderFromCred decoder =
    Decode.map2 (\fromCred cred -> fromCred cred)
        decoder
        credDecoder


-- ERRORS


addServerError : List String -> List String
addServerError list =
    "Server error" :: list


decodeErrors : Http.Error -> List String
decodeErrors error =
    case error of
        Http.BadUrl s ->
            ["Bad URL " ++ s]
        Http.Timeout ->
            ["Connection timed out"]
        Http.NetworkError ->
            ["Network Error"]
        Http.BadStatus code ->
            ["Server Returned Code: " ++ (String.fromInt code)]
        Http.BadBody s ->
            ["Bad Body " ++ s]


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
