from __future__ import print_function
from flask import Flask, request, jsonify
import random
import string
from flask_socketio import SocketIO
import sys

import spacy
from spacy.matcher import PhraseMatcher
import en_core_med7_lg

async_mode = None
med7 = en_core_med7_lg.load()
app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app, async_mode=async_mode, ping_timeout=10000)

nlp = spacy.load('./medOP')

#helper functions
def randomString(stringLength=8):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(stringLength))


def handle_disconnect():
    print('disconnected', file=sys.stderr)


@socketio.on('connect')
def handle_message():
    print('received socket', file=sys.stderr)
    socketio.emit('message', {'data': '12'})
    socketio.on_event('disconnect', handle_disconnect)
    return "Connected!!!"

def get_medicine_details(text):
  prescription={}
  doc = med7(text)
  for ent in doc.ents:
    prescription[ent.label_]=ent.text
  return prescription

def get_final_prescription(response,transcript):
  final_response={'medicines':[]}
  for index,item in enumerate(response):
    detailed_medicine={}
    if ((index+1)>=len(response)):
      end=len(transcript)
    else:
      end=response[index+1][2]
    start=item[2]
    medicine=item[0]
    print("Test 3",transcript[start:end])
    result=get_medicine_details(transcript[start:end])
    detailed_medicine['medicine']=medicine
    detailed_medicine['dosage']=result['DOSAGE'] if (result.get('DOSAGE')!=None) else ''
    detailed_medicine['strength']=result['STRENGTH'] if (result.get('STRENGTH')!=None) else ''
    detailed_medicine['form']=result['FORM'] if (result.get('FORM')!=None) else ''
    detailed_medicine['route']=result['ROUTE'] if (result.get('ROUTE')!=None) else ''
    
    detailed_medicine['frequency']=result['FREQUENCY'] if (result.get('FREQUENCY')!=None) else ''
    detailed_medicine['duration']=result['DURATION'] if (result.get('DURATION')!=None) else ''

    detailed_medicine['onone'] = onoone(detailed_medicine['frequency'])
    print("Test 4",final_response)
    print("Test 5",detailed_medicine)
    print("Test 6",onoone(detailed_medicine['frequency']))
    final_response['medicines'].append(detailed_medicine)
  return final_response

def onoone(text):
    x=[]
    t=(text.find('morning'), text.find('afternoon'),text.find('night'))
    for i in t:
        if i>=0:
            x.append("1")
        else:
            x.append("0")
    return "-".join(x)



#API routes
@app.route('/')
def home():
    print('BASE URL API ', file=sys.stderr)
    return jsonify({"message": "BASE FLASK URL"})


@app.route('/api/test/<message>')
def model(message):
    socketio.emit(message, {'data': 42})
    return jsonify({"message": "running socket to emit message"})


@app.route('/api/model/process', methods=['POST'])
def modelProcess():
    data = request.json
    print("DATA", data)
    socketId = data['doctor']['filename'][:-5]
    print(socketId, file=sys.stderr)
    socketio.emit('message', data)
    data = request.json
    transcript = data['doctor']['doc']['text']
    doc=nlp(transcript)
    preReady = [(ent.text, ent.label_,ent.start_char, ent.end_char) for ent in doc.ents]
    print("Test",preReady)
    socketio.emit('message', preReady)
    resp = get_final_prescription(preReady,transcript)
    print("Test2",resp)  
    socketio.emit('message', resp)
    socketio.emit(socketId, resp)
    return jsonify({
        "message": "running socket to emit message",
        "sockId": socketId
    })



# def find_symptoms(data):
#     print("Entered FIND SYMPTOMS")
#     doc = nlp(data)
#     response = {
#         'message': "This is your response"
#     }
#     symptoms = " "
#     intensity = " "
#     entities = [(ent.text, ent.label_) for ent in doc.ents]
#     for item in entities:
#         if item[1] == 'SYMPTOMS':
#             symptoms += item[0] + ', '
#         if item[1] == 'INTENSITY':
#             intensity += item[0] + ', '

#     if symptoms.strip:
#         response['symptoms'] = symptoms[:-2].strip()
#     if intensity.strip():
#         response['intensity'] = intensity[:-2].strip()
    
#     return response



if __name__ == "__main__":
    socketio.run(app, host='0.0.0.0', port=5000)
