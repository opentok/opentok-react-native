import React, { Component } from 'react';
import { PropTypes } from 'prop-types';
import { requireNativeComponent, Platform, View } from 'react-native';

class OTPublisherView extends Component {
  render() {
    return <ReactPublisher {...this.props} />;
  }
}
const viewPropTypes = View.propTypes;
OTPublisherView.propTypes = {
  publisherId: PropTypes.string.isRequired,  
  ...viewPropTypes,
};

const publisherName = Platform.OS === 'ios' ? 'OTPublisherSwift' : 'OTPublisherViewManager';
const ReactPublisher = requireNativeComponent(publisherName, OTPublisherView);
export default OTPublisherView;
