module Pushfight.Move exposing (Move, decodeMove)

import Json.Decode as Decode exposing (Decoder)

type alias Move =
	{ from: Int
	, to: Int
	}


decodeMove : Decode.Decoder Move
decodeMove =
    Decode.map2 Move
        (Decode.field "from" Decode.int)
        (Decode.field "to" Decode.int)
