module Main exposing (Model, Msg(..), init, initialModel, main, subscriptions, update, view)

-- IMPORTS

import Browser
import Browser.Events
import Html
import Html.Attributes
import Math.Matrix4
import Math.Vector3
import WebGL



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { currentTime : Float }


type alias Time =
    Float


type alias Triangle =
    ( Vertex, Vertex, Vertex )


type alias Uniforms =
    { perspective : Math.Matrix4.Mat4 }


type alias Vertex =
    { position : Math.Vector3.Vec3
    , color : Math.Vector3.Vec3
    }


initialModel : Model
initialModel =
    { currentTime = 0 }


init : () -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )



-- UPDATE


type Msg
    = GameLoop Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GameLoop elapsed ->
            ( { model | currentTime = model.currentTime + elapsed }, Cmd.none )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Browser.Events.onAnimationFrameDelta GameLoop



-- VIEW


view : Model -> Html.Html msg
view model =
    Html.div []
        [ webGL model ]



-- WebGL


webGL : Model -> Html.Html msg
webGL model =
    WebGL.toHtml
        [ Html.Attributes.width 400
        , Html.Attributes.height 400
        , Html.Attributes.style "background-color" "black"
        , Html.Attributes.style "display" "block"
        ]
        [ entity model ]



-- ENTITY


entity : Model -> WebGL.Entity
entity model =
    WebGL.entity
        vertexShader
        fragmentShader
        mesh
        { perspective = perspective (model.currentTime / 1000) }


perspective : Float -> Math.Matrix4.Mat4
perspective t =
    Math.Matrix4.mul
        (Math.Matrix4.makePerspective 45 1 0.01 100)
        (Math.Matrix4.makeLookAt (Math.Vector3.vec3 (4 * cos t) 0 (4 * sin t)) (Math.Vector3.vec3 0 0 0) (Math.Vector3.vec3 0 1 0))



-- VERTEX SHADER


vertexShader : WebGL.Shader Vertex Uniforms { vcolor : Math.Vector3.Vec3 }
vertexShader =
    [glsl|
        attribute vec3 position;
        attribute vec3 color;
        uniform mat4 perspective;
        varying vec3 vcolor;
        void main () {
            gl_Position = perspective * vec4(position, 1.0);
            vcolor = color;
        }
    |]



-- FRAGMENT SHADER


fragmentShader : WebGL.Shader {} Uniforms { vcolor : Math.Vector3.Vec3 }
fragmentShader =
    [glsl|
        precision mediump float;
        varying vec3 vcolor;
        void main () {
            gl_FragColor = vec4(vcolor, 1.0);
        }
    |]



-- MESH


mesh : WebGL.Mesh Vertex
mesh =
    WebGL.triangles
        [ triangle ]


triangle : Triangle
triangle =
    ( { position = Math.Vector3.vec3 0 0 0, color = Math.Vector3.vec3 1 0 0 }
    , { position = Math.Vector3.vec3 1 1 0, color = Math.Vector3.vec3 0 1 0 }
    , { position = Math.Vector3.vec3 1 -1 0, color = Math.Vector3.vec3 0 0 1 }
    )



{-
    WebGL Learning

   - Scene
   - Camera
   - Lightning

   - Meshes: Small triangles to create shapes.
     - Data points and colors to render to screen.
     - Each triangle corner is a vertex.
   - Shaders: Turn meshes into pictures.
     - Vertex: Move triangles around and change color.
     - Fragment: Pixel effects like lighting and blur.
   - Data Flow Variables
     - Uniform: Global read-only variables defined on the CPU.
     - Attribute: Represent a vertex.
     - Varying: From vertex shader to fragment shader.
   - CPU and GPU Performance
     - Typical meshes can consist of thousands of vertices.
     - CPU works sequentially, while GPU works parallel.
     - Transferring data from CPU to GPU is expensive, so use uniform variables.
     - Cache known meshes on the GPU.
-}
