module Page.PlayingGame exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
--import Html.Events exposing (onInput)
import Html.Events exposing (onClick)
import Route

import Api exposing (Cred, Color(..))
import Session exposing (Session)


type alias Model =
    { session : Session
    , gameId : String
    --, gameColor : Color
    }

init : Session -> String -> (Model, Cmd Msg)
init session gameId =
    (
        { session = session
        , gameId = gameId
        }
    ,
        Cmd.none
    )


-- VIEW

view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Game " ++ model.gameId
    , content = div []
        [ div [] [text "Let's play some pushfight!"]
        , div [] [button [onClick BackToLobby] [text "Back To Lobby"] ]
        ]
    }


-- UPDATE

type Msg
    = BackToLobby
    | GotSession Session

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BackToLobby ->
            (model, Route.replaceUrl (Session.navKey model.session) Route.Home)

        GotSession session ->
            ({model | session = session}, Cmd.none)

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
