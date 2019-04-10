import React from 'react';
import { PropTypes } from 'prop-types';
import { requireNativeComponent, Platform, View } from 'react-native';

const OTPublisherView = props => (<ReactPublisher {... props} />);

const viewPropTypes = View.propTypes;
OTPublisherView.propTypes = {
  publisherId: PropTypes.string.isRequired,
  ...viewPropTypes,
};

const publisherName = Platform.OS === 'ios' ? 'OTPublisherSwift' : 'OTPublisherViewManager';
const ReactPublisher = requireNativeComponent(publisherName, OTPublisherView);
export default OTPublisherView;
