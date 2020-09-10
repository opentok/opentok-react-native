import React from 'react';
import renderer from 'react-test-renderer';

import OTSubscriber from '../src/OTSubscriber';

jest.mock('../src/OT', () => ({
  nativeEvents: jest.fn()
}));

describe('OTSubscriber', () => {
  describe('no props', () => {
    it('should render an empty view', () => {
      const subscriber = renderer.create(<OTSubscriber />).toJSON();
      expect(subscriber).toMatchSnapshot();
    });
  });

  describe('with props', () => {

  });
});
