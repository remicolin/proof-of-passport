import React, { useState, useEffect} from 'react';
import { YStack, XStack, Text, Button, SizableText, Tabs, styled , Dialog, Adapt, Sheet, Label , Fieldset, Input, Switch ,ThemeableStack} from 'tamagui'
import { Scan, UserCheck , HelpCircle, XCircle , IterationCw} from '@tamagui/lucide-icons'; 
import ScanScreen from './ScanScreen';
import ProveScreen from './ProveScreen';
import { Steps } from '../utils/utils';

const MainScreen = (
    {onStartCameraScan,
    nfcScan,
    passportData,
    disclosure,
    handleDisclosureChange,
    address,
    setAddress,
    generatingProof,
    handleProve,
    step,
    mintText ,
    proof,
    proofTime,
    handleMint,
    totalTime,
    setStep,
    passportNumber,
    setPassportNumber,
    dateOfBirth,
    setDateOfBirth,
    dateOfExpiry,
    setDateOfExpiry
    }
) => {
  const [selectedTab, setSelectedTab] = useState("scan");
  const [brokenCamera,setBrokenCamera] = useState(false);
  const [open, setOpen] = useState(false)
  const MyCard = styled(ThemeableStack, {
    hoverTheme: true,
    pressTheme: true,
    focusTheme: true,
    elevate: true
  })
  const handleRestart = () => {
    setStep(Steps.MRZ_SCAN);
    setPassportNumber("");
    setDateOfBirth("");
    setDateOfExpiry("");

  }
  useEffect(() => {
    // Check if length of each field is correct and move to step MRZ_SCAN_COMPLETED if so
    if (passportNumber?.length === 9 && (dateOfBirth?.length === 6 && dateOfExpiry?.length === 6)) {
        setStep(Steps.MRZ_SCAN_COMPLETED);
    }
}, [passportNumber, dateOfBirth, dateOfExpiry]);

  return (
    <YStack f={1} ai="center" jc="space-between" bc="#fff">
        
        <YStack w="100%">
        <XStack w="100%" jc="space-between" ai="center" ph="$4" pv="$2" bc="#fff" p="$3">
            <XStack></XStack>
            <Text>{selectedTab==="scan"?"Scan":"Prove"}</Text>

            <Dialog
      modal
      onOpenChange={(open) => {
        setOpen(open)
      }}
    >
      <Dialog.Trigger asChild p="$2">
        <HelpCircle/>
      </Dialog.Trigger>

      <Adapt when="sm" platform="touch">
        <Sheet animation="medium" zIndex={200000} modal dismissOnSnapToBottom>
          <Sheet.Frame padding="$4" gap="$4">
            <Adapt.Contents />
          </Sheet.Frame>
          <Sheet.Overlay
            animation="lazy"
            enterStyle={{ opacity: 0 }}
            exitStyle={{ opacity: 0 }}
          />
        </Sheet>
      </Adapt>

      <Dialog.Portal>
        <Dialog.Overlay
          key="overlay"
          animation="quick"
          opacity={0.5}
          enterStyle={{ opacity: 0 }}
          exitStyle={{ opacity: 0 }}
        />

        <Dialog.Content
          bordered
          elevate
          key="content"
          animateOnly={['transform', 'opacity']}
          animation={[
            'quick',
            {
              opacity: {
                overshootClamping: true,
              },
            },
          ]}
          enterStyle={{ x: 0, y: -20, opacity: 0, scale: 0.9 }}
          exitStyle={{ x: 0, y: 10, opacity: 0, scale: 0.95 }}
          gap="$4"
        >
            <XStack space >
            <Dialog.Title>Settings</Dialog.Title>

            </XStack>

            <Fieldset gap="$4" mt="$2" horizontal>
            <Label width={160} justifyContent="flex-end" htmlFor="name" fow="bold">
              Restart to step 1
            </Label>
            <Button size="$4" m="$2" onPress={handleRestart}>
            <IterationCw/>
            </Button>
          </Fieldset>
          <Fieldset gap="$4" mt="$2" horizontal>
            <Label width={160} justifyContent="flex-end" htmlFor="name" fow="bold">
              Broken camera
            </Label>
            <Switch size="$4" checked={brokenCamera} onCheckedChange={setBrokenCamera}>
                <Switch.Thumb animation="bouncy" backgroundColor="white" color/>
            </Switch>
          </Fieldset>
          {
            brokenCamera &&
          <YStack space pl="$3">
          <Fieldset gap="$4" horizontal>
            <Label width={160} justifyContent="flex-end" htmlFor="name">
              Passport Number
            </Label>
            <Input borderColor={passportNumber?.length === 9? "green":"unset"} flex={1} id="passport_number" onChangeText={(text) => setPassportNumber(text.toUpperCase())} value={passportNumber} keyboardType="default"/>
          </Fieldset>
          <Fieldset gap="$4" mt="$2" horizontal>
            <Label width={160} justifyContent="flex-end" htmlFor="name">
              Date of birth (yymmdd)
            </Label>
            <Input borderColor={dateOfBirth?.length === 6? "green":"unset"}  flex={1} id="date_of_birth" onChangeText={setDateOfBirth} value={dateOfBirth}  keyboardType="numeric"/>
          </Fieldset>
          <Fieldset gap="$4" mt="$2" horizontal>
            <Label width={160} justifyContent="flex-end" htmlFor="name">
              Date of expiry (yymmdd)
            </Label>
            <Input borderColor={dateOfExpiry?.length === 6? "green":"unset"}  flex={1} id="date_of_expiry" onChangeText={setDateOfExpiry} value={dateOfExpiry} keyboardType="numeric"/>
          </Fieldset>
          </YStack>
          }
          <YStack flex={1}>
          <YStack flex={1}></YStack>
          <Dialog.Close mb="$4" displayWhenAdapted asChild alignSelf='center'>
                <XCircle size="$3"/>
            </Dialog.Close>

          </YStack>

        </Dialog.Content>
      </Dialog.Portal>
    </Dialog>

        </XStack>
        <YStack  w="100%" h={2} backgroundColor="#DCDCDC" opacity={0.16}></YStack>
        </YStack>


        <Tabs f={1} defaultValue="scan" orientation='horizontal' dir='ltr' shadowColor="black" onValueChange={(newValue) => setSelectedTab(newValue)}>
            <YStack f={1} ai="center"  jc="space-between" >
                <XStack/>

                <Tabs.Content value="scan">
                    <ScanScreen
                      onStartCameraScan={onStartCameraScan}
                      nfcScan = {nfcScan}
                      step={step}/>
                </Tabs.Content>
                <Tabs.Content value="generate">
                <ProveScreen
                    passportData={passportData}
                    disclosure={disclosure}
                    handleDisclosureChange={handleDisclosureChange}
                    address={address}
                    setAddress={setAddress}
                    generatingProof={generatingProof}
                    handleProve={handleProve}
                    step={step}
                    mintText={mintText}
                    proof={proof}
                    proofTime={proofTime}
                    handleMint={handleMint}
                    totalTime={totalTime}
                    setStep = {setStep}
                    />
                 </Tabs.Content>
                
                <YStack w="100%" backgroundColor="white">
                <YStack  w="100%" h={2} backgroundColor="#DCDCDC" opacity={0.16}></YStack>
                <Tabs.List w="100%" pt="$4" pb="$3">
                    <Tabs.Tab unstyled value="scan" w="50%" backgroundColor="transparent" >
                        <YStack ai="center">
                            <Scan color={selectedTab=== "scan"? '#3185FC' : 'black'} /> 
                            <SizableText color={selectedTab=== "scan"? '#3185FC' : 'black'}>Scan</SizableText>
                        </YStack>
                    </Tabs.Tab>
                    {step < Steps.NFC_SCAN_COMPLETED ?
                                    <Tabs.Tab unstyled value="scan" w="50%" backgroundColor="transparent">
                                        <YStack ai="center">
                                            <UserCheck  color="#eeeeee"/> 
                                            <SizableText color="#eeeeee">Prove</SizableText>
                                        </YStack>
                                    </Tabs.Tab>
                                    :
                                    <Tabs.Tab unstyled value="generate" w="50%" backgroundColor="transparent">
                                    <YStack ai="center">
                                        <UserCheck  color={selectedTab=== "generate"? '#3185FC' : 'black'}/> 
                                        <SizableText color={selectedTab=== "generate"? '#3185FC' : 'black'}>Prove</SizableText>
                                    </YStack>
                                </Tabs.Tab>
                    }
                </Tabs.List>
                </YStack>
            </YStack>
        </Tabs>      
    </YStack>
  );
};

export default MainScreen;
