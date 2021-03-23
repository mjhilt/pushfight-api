module Api.Endpoint exposing (Endpoint, gameChallenge, gameJoin, gameStart, gameStatus, login, move, mygames, opengames, register, unwrap)

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



-- POST


login =
    url [ "login" ] []


register : Endpoint



-- POST


register =
    url [ "register" ] []


opengames : Endpoint



-- GET


opengames =
    url [ "opengames" ] []


mygames : Endpoint



-- GET


mygames =
    url [ "mygames" ] []


gameChallenge : Endpoint



-- POST


gameChallenge =
    url [ "game", "challenge" ] []


gameStart : Endpoint



-- POST


gameStart =
    url [ "game", "start" ] []


gameJoin : Endpoint



-- POST


gameJoin =
    url [ "game", "join" ] []


gameStatus :
    Int
    -> Endpoint -- GET
gameStatus uuid =
    url [ "game", "status" ] [ Url.Builder.int "game" uuid ]


move : Endpoint



-- POST


move =
    url [ "move" ] []
