const express = require("express");
const mongoose = require("mongoose");
const { Dog } = require("./models");
const connection_string = `mongodb://${process.env.USERNAME}:${process.env.PASSWORD}@mongosrv:27017`;
const app = express();
mongoose.connect(connection_string, function(err) {
    if (err) {
        console.error(err);
    } else {
        console.log("connected to mongo");
        app.listen(3000, () => console.log("Server started on port 3000"));
    }    
});
app.get("/", async (req, res) => {
    console.log("Incoming request");
    const allDogs = await Dog.find();
    console.log("Finished Querying");
    return res.status(200).json(allDogs);
  });
