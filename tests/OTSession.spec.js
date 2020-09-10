import React from 'react';
import { mount } from 'enzyme';
import toJson from 'enzyme-to-json';
import { Text } from 'react-native';

import OTSession from '../src/OTSession';
import { OT } from '../src/OT';
import { logOT } from '../src/helpers/OTHelper';

jest.mock('../src/OT', () => ({
  OT: {
    disconnectSession: jest.fn(),
    initSession: jest.fn(),
    connect: jest.fn()
  },
  setNativeEvents: jest.fn()
}));

jest.mock('../src/helpers/OTHelper', () => ({
  logOT: jest.fn(),
  getLog: jest.fn(),
  logRequest: jest.fn(),
  getOtrnErrorEventHandler: jest.fn(),
  reassignEvents: jest.fn()
}));

describe('OTSession', () => {
  let apiKey, sessionId, token;

  beforeEach(() => {
    apiKey = 'fakeApiKey';
    sessionId = 'fakeSessionId';
    token = 'fakeToken';
  });

  describe('no props', () => {
    let sessionComponent;
    console.error = jest.fn();
    console.log = jest.fn();

    beforeEach(() => {
      console.error.mockClear();
      sessionComponent = mount(<OTSession />);
    });

    describe('missing credentials', () => {

      it('should render an empty view', () => {
        expect(toJson(sessionComponent)).toMatchSnapshot();
      });

      it('should call console error', () => {
        expect(console.error).toHaveBeenCalled();
        expect(console.error).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('with props and children', () => {
    let sessionComponent;
    let instance;

    beforeEach(() => {
      sessionComponent = mount(
        <OTSession apiKey={apiKey} sessionId={sessionId} token={token}>
          <Text />
          <Text />
        </OTSession>
      );

      instance = sessionComponent.instance();
    });

    it('should have two children', () => {
      expect(toJson(sessionComponent)).toMatchSnapshot();
    });

    describe('when component mounts', () => {
      beforeEach(() => {
        jest.spyOn(instance, 'createSession');
        instance.componentDidMount();
      });

      it('should call createSession', () => {
        expect(instance.createSession).toHaveBeenCalledTimes(1);
      });

      it('should call OT.initSession', () => {
        expect(OT.initSession).toHaveBeenCalled();
      });

      it('should call OT.connect', () => {
        expect(OT.connect).toHaveBeenCalled();
      });

      it('should call logOT', () => {
        expect(logOT).toHaveBeenCalled();
      });
    });

    describe('when component unmounts', () => {
      beforeEach(() => {
        jest.spyOn(instance, 'disconnectSession');
        sessionComponent.unmount();
      });

      it('should call disconnectSession', () => {
        expect(instance.disconnectSession).toHaveBeenCalled();
      });
    });
  });
});
