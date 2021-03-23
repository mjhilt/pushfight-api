module Pushfight.Move exposing (Move, decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Move =
    { from : Int
    , to : Int
    }


decode : Decode.Decoder Move
decode =
    Decode.map2 Move
        (Decode.field "from" Decode.int)
        (Decode.field "to" Decode.int)


encode : Move -> Encode.Value
encode move =
    Encode.object
        [ ( "from", Encode.int move.from )
        , ( "to", Encode.int move.to )
        ]
