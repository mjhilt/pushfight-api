module Pushfight.DragState exposing (Drag, Model, MousePosition, Msg(..), init, subscriptions, update)


import Browser.Events
import Json.Decode as Decode exposing (Decoder)



-- model


type alias MousePosition =
    { x : Int
    , y : Int
    }


type alias Drag =
    { from : MousePosition
    , to : MousePosition
    }


type Model
    = NotDragging
    | Dragging Drag



-- init


init : Model
init =
    NotDragging



-- update


type Msg
    = MouseDown MousePosition
    | MouseUp MousePosition
    | MouseMove MousePosition


update : Msg -> Model -> ( Model, Maybe Drag )
update msg model =
    case ( model, msg ) of
        ( NotDragging, MouseDown pos ) ->
            ( Dragging { from = pos, to = pos }, Nothing )

        ( Dragging drag, MouseUp pos ) ->
            ( NotDragging, Just { drag | to = pos } )

        ( Dragging drag, MouseMove pos ) ->
            ( Dragging { drag | to = pos }, Nothing )

        ( ds, _ ) ->
            ( ds, Nothing )



-- subscriptions


decodePosition : Decode.Decoder MousePosition
decodePosition =
    Decode.map2 MousePosition
        (Decode.field "pageX" Decode.int)
        (Decode.field "pageY" Decode.int)


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Browser.Events.onMouseDown (Decode.map MouseDown decodePosition)
        , Browser.Events.onMouseMove (Decode.map MouseMove decodePosition)
        , Browser.Events.onMouseUp (Decode.map MouseUp decodePosition)
        ]



-- helpers


getDrag : Model -> Maybe Drag
getDrag dragState =
    case dragState of
        NotDragging ->
            Nothing

        Dragging drag ->
            Just drag
