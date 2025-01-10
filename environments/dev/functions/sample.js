module.exports.handler = async (event) => {
  console.log("Event: ", event);
  const responseMessage = "Congluts! Your can reach the function!";

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: responseMessage,
    }),
  };
};
