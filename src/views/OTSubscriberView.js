import React, { Component } from 'react';
import { PropTypes } from 'prop-types';
import { requireNativeComponent, Platform, View } from 'react-native';

class OTSubscriberView extends Component {
  render() {
    return <ReactSubscriber {...this.props} />;
  }
}
const viewPropTypes = View.propTypes;
OTSubscriberView.propTypes = {
  streamId: PropTypes.string.isRequired,
  ...viewPropTypes,
};

const subscriberName = Platform.OS === 'ios' ? 'OTSubscriberSwift' : 'OTSubscriberViewManager';
const ReactSubscriber = requireNativeComponent(subscriberName, OTSubscriberView);
export default OTSubscriberView;
