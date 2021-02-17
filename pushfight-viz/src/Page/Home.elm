module Page.Home exposing (Model, Msg, init, subscriptions, toSession, update, view)

{-| The homepage. You can get here via either the / or /#/ routes.
-}

import Api exposing (Cred)
import Api.Endpoint as Endpoint
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder)
import Html.Events exposing (onClick)
import Http
--import Loading
--import Log
import Page
--import PaginatedList exposing (PaginatedList)
import Session exposing (Session)
import Task exposing (Task)
import Time
import Url.Builder
import Username exposing (Username)



-- MODEL


type alias Model =
    { session : Session
    }


type FeedTab
    = YourFeed Cred
    | GlobalFeed
    | TagFeed Tag


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      }
    , Cmd.none
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Home"
    , content = div [] [text "Welcome To Pushfight"]
    }


-- UPDATE


type Msg
    = NoOp

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp tag ->
            (model, Cmd.none)


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
