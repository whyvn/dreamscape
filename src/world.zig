const World = struct {
    // use delta values for movement.
    // no concrete values neccessary

    pos: struct {
        x: f32,
        y: f32,
        z: f32
    },

    camera: struct {
        yaw: f32,
        pitch: f32,
        roll: f32,
        // fov: f32,

        // enabled: bool = true
    },

};

// TODO: generate constant shader `COLOURS` based on texture colours or something
