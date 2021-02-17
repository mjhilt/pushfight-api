module Page.Settings exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)

import Route exposing (Route)
import Session exposing (Session)
import Viewer exposing (Viewer)

-- Model

type alias Model =
    { session : Session
    , notifications: Bool
    }


init : Session -> ( Model, Cmd msg )
init session =
    ( { session = session
      , notifications = False
      }
    , Cmd.none
    )

-- UPDATE

type Msg
    = ToggleNotifications
    | GotSession Session
    | GotSession Session


update : Msg -> Model -> Model
update msg model =
  case msg of
    ToggleNotifications ->
      { model | notifications = not model.notifications}



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Settings"
    , content =
        let
            buttonText =
                if model.notifications then
                    "Disable Notifications"
                else
                    "Enable Notifications"
        in
          div []
            [ button [ onClick ToggleNotifications ] [ text "-" ]
            ]
    }


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
