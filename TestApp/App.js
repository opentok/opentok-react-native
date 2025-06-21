/* eslint-disable react-native/no-inline-styles */
import React, {Component} from 'react';
import {View} from 'react-native';
import {OTSession, OTPublisher, OTSubscriber} from 'opentok-react-native';

class App extends Component {
  constructor(props) {
    super(props);
    this.apiKey = '47120344';
    this.sessionId = '2_MX40NzEyMDM0NH5-MTcxNDc1MzQ4MDc2MH43eVVvZGRKL2R0WVZUVUNFektKaEZOOHh-fn4';
    this.token = 'T1==cGFydG5lcl9pZD00NzEyMDM0NCZzaWc9MDE0ODBlZDAwZWEyYzE2OGY1MWZiYzRhYWVlNDM2OWNiYzAxYmZjYzpzZXNzaW9uX2lkPTJfTVg0ME56RXlNRE0wTkg1LU1UY3hORGMxTXpRNE1EYzJNSDQzZVZWdlpHUktMMlIwV1ZaVVZVTkZla3RLYUVaT09IaC1mbjQmY3JlYXRlX3RpbWU9MTcxNDc1MzQ4MSZub25jZT0wLjkyNTcwOTIyMzAzMDk0NCZyb2xlPW1vZGVyYXRvciZleHBpcmVfdGltZT0xNzE3MzQ1NDgxJmluaXRpYWxfbGF5b3V0X2NsYXNzX2xpc3Q9';
  }

  render() {
    return (
      <View
        style={{
          flex: 1,
          flexDirection: 'column',
          paddingHorizontal: 100,
          paddingVertical: 50,
        }}>
        <OTSession
          apiKey={this.apiKey}
          sessionId={this.sessionId}
          token={this.token}>
          <OTPublisher style={{width: 200, height: 200}} />
          <OTSubscriber style={{width: 200, height: 200}} />
        </OTSession>
      </View>
    );
  }
}

export default App;
