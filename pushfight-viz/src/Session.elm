module Session exposing (Session, changes, cred, fromViewer, navKey)

import Api exposing (Cred, credDecoder)
import Avatar exposing (Avatar)
import Browser.Navigation as Nav
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (custom, required)
import Json.Encode as Encode exposing (Value)
import Time
import Viewer exposing (Viewer)



-- TYPES


type Session
    = LoggedIn Nav.Key Cred
    | Guest Nav.Key



-- INFO


--viewer : Session -> Maybe Cred
--viewer session =
--    case session of
--        LoggedIn _ val ->
--            Just val

--        Guest _ ->
--            Nothing


cred : Session -> Maybe Cred
cred session =
    case session of
        LoggedIn _ cred ->
            Just cred

        Guest _ ->
            Nothing


navKey : Session -> Nav.Key
navKey session =
    case session of
        LoggedIn key _ ->
            key

        Guest key ->
            key



-- CHANGES


changes : (Session -> msg) -> Nav.Key -> Sub msg
changes toMsg key =
    Api.viewerChanges (\maybeCred -> toMsg (fromViewer key maybeCred)) credDecoder


fromViewer : Nav.Key -> Maybe Cred -> Session
fromViewer key maybeCred =
    -- It's stored in localStorage as a JSON String;
    -- first decode the Value as a String, then
    -- decode that String as JSON.
    case maybeCred of
        Just viewerVal ->
            LoggedIn key viewerVal

        Nothing ->
            Guest key
