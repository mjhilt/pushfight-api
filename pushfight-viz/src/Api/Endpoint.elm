module Api.Endpoint exposing (Endpoint, get, post, unwrap, login, opengames, mygames, gameChallenge, gameStart, gameJoin, gameStatus, move)
import Http


import Url.Builder exposing (QueryParameter)
import Username exposing (Username)

get: Endpoint -> Http.Expect msg -> Cmd msg
get e expect =
    Http.get
        { url = unwrap e
        , expect = expect
        }


post: Endpoint -> Http.Body -> Http.Expect msg -> Cmd msg
post e body expect =
    Http.post
        { url = unwrap e
        , body = body
        , expect = expect
        }


-- TYPES


{-| Get a URL to the Conduit API.
This is not publicly exposed, because we want to make sure the only way to get one of these URLs is from this module.
-}
type Endpoint
    = Endpoint String


unwrap : Endpoint -> String
unwrap (Endpoint str) =
    str


url : List String -> List QueryParameter -> Endpoint
url paths queryParams =
    -- NOTE: Url.Builder takes care of percent-encoding special URL characters.
    -- See https://package.elm-lang.org/packages/elm/url/latest/Url#percentEncode
    Url.Builder.absolute paths queryParams
        |> Endpoint



-- ENDPOINTS

login : Endpoint -- POST
login = 
    url ["login"] []

opengames : Endpoint -- GET
opengames = 
    url ["opengames"] []

mygames : Int -> Endpoint -- GET
mygames uuid = 
    url ["mygames"] [Url.Builder.int "user" uuid]

gameChallenge : Endpoint -- POST
gameChallenge = 
    url ["game", "challenge"] []

gameStart : Endpoint -- POST
gameStart = 
    url ["game", "start"] []

gameJoin : Endpoint -- POST
gameJoin = 
    url ["game", "join"] []

gameStatus : Int -> Endpoint -- GET
gameStatus uuid = 
    url ["game", "status"] [Url.Builder.int "game" uuid]

move : Endpoint -- POST
move = 
    url ["move"] []
