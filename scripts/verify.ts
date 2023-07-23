export async function verify(hre, address, constructorArguments) {
  await hre
    .run('verify:verify', {
      address: address,
      constructorArguments: constructorArguments,
    })
    .then(() => {
      console.log(`Verified of ${address}`);
    })
    .catch((e) => {
      console.log(
        `Verification of ${address} failed with ${JSON.stringify(e, null, 2)}`,
      );
    });
}