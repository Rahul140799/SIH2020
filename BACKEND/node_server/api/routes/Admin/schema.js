const Joi = require('@hapi/joi');


module.exports.adminLoginSchema = Joi.object({
    name: Joi.string().required(),
    password: Joi.string().min(8).required()
});