const handleError = (error) => {
  console.log('OTRN JS: There was an error: ', error);
};

const handleSignalError = (error) => {
  if (error) {
    console.log(`OTRN JS: There was an error sending the signal ${error}`);
  }
};

export {
  handleError,
  handleSignalError,
};
