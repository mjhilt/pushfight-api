module Api.Endpoint exposing (Endpoint, gameChallenge, gameJoin, gameStart, login, move, mygames, opengames, register, unwrap, update)

import Http
import Url.Builder exposing (QueryParameter)
import Username exposing (Username)



--request :
--    { method : String
--    , headers : List Header
--    , url : String
--    , body : Body
--    , expect : Expect msg
--    , timeout : Maybe Float
--    , tracker : Maybe String
--    }
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
    Url.Builder.absolute ("1" :: paths) queryParams
        |> Endpoint



-- ENDPOINTS


login : Endpoint
login =
    url [ "login" ] []


register : Endpoint
register =
    url [ "register" ] []


opengames : Endpoint
opengames =
    url [ "opengames" ] []


mygames : Endpoint
mygames =
    url [ "mygames" ] []


gameChallenge : Endpoint
gameChallenge =
    url [ "game", "challenge" ] []


gameStart : Endpoint
gameStart =
    url [ "game", "start" ] []


gameJoin : Endpoint
gameJoin =
    url [ "game", "join" ] []



--gameStatus :
--    String
--    -> Endpoint
--gameStatus uuid =
--    --url [ "game", "status", uuid ] [] -- [ Url.Builder.string "game" uuid ]
--    url [ "game", "status" ] [ Url.Builder.string "game" uuid ]
--gameStatus : Endpoint
--gameStatus =
--    url [ "game", "status" ] []


move : Endpoint
move =
    url [ "move" ] []


update : Endpoint
update =
    url [ "update" ] []
