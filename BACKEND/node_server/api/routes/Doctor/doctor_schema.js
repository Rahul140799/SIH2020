const Joi = require('@hapi/joi');
const mongoose = require('mongoose');
const { date, string } = require('@hapi/joi');

module.exports.doctorSchema = Joi.object({
    name: Joi.string().required(),
    phno: Joi.string().min(10).max(10).required(),
    email: Joi.string().min(6).required().email(),
    password: Joi.string().min(8).required()
});

module.exports.doctorLoginSchema = Joi.object({
    address: Joi.string().required(),
    password: Joi.string().min(8).required()
});

module.exports.appointmentSchemaCheck = Joi.object({
    doctorAddress : Joi.string().required(),
    patientQrCode : Joi.string().required(),
    time : Joi.string().required(),
    date: Joi.string().required()
});

module.exports.addQuestionSchema = Joi.object({
    appointmentNumber: Joi.number().required(),
    questions: Joi.array().required(),
    dateToAsk : Joi.string().required() 
});

module.exports.getAnswerSchema = Joi.object({
    doctorAddress: Joi.string().required(),
    patientAddress: Joi.string().required()
});

const appointmentSchema = mongoose.Schema({
    _id : mongoose.Schema.Types.ObjectId,
    doctorAddress : String,
    patientQrCode : String,
    appointmentNumber : Number,
    time : String,
    date : Date,
    visited : Boolean,
    questions : [String],
    answers :[String],
    answered: Boolean,
    dateToAsk : Date
});

module.exports.appointmentSchema = mongoose.model('Appointment', appointmentSchema);